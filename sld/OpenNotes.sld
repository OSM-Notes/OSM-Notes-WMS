<?xml version="1.0" encoding="UTF-8"?>
<!--
SLD file with red color scale for open OSM notes.
Colors based on age_years (years since creation).
Different shapes based on country_shape_mod (id_country % 6): 0 triangle, 1 circle,
2 square, 3 star, 4 shape://carrow, 5 arrow. International waters: -1.

Color scale (recent = bright red, old = dark toward black with transparency):
- 0 years: Bright red (#FF0000), opacity 1.0
- 1-2 years: Medium red (#CC0000), opacity 0.9
- 3-4 years: Dark red (#990000), opacity 0.7
- 5-6 years: Very dark red (#660000), opacity 0.5
- 7-8 years: Almost black red (#330000), opacity 0.3
- 9+ years: Black (#000000), opacity 0.2

Author: Andres Gomez (AngocA)
Version: 2025-12-30
-->
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:se="http://www.opengis.net/se" xmlns:ogc="http://www.opengis.net/ogc" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd" version="1.1.0">
  <NamedLayer>
    <se:Name>notes open</se:Name>
    <UserStyle>
      <se:Name>notes open</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:Name>0 years - International Waters - Bright Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FF0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>0 years - Shape 0 - Bright Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FF0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>0 years - Shape 1 - Bright Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FF0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>0 years - Shape 2 - Bright Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FF0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>0 years - Shape 3 - Bright Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FF0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>0 years - Shape 4 - Bright Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FF0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>0 years - Shape 5 - Bright Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FF0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>1-2 years - International Waters - Medium Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#CC0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>1-2 years - Shape 0 - Medium Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#CC0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>1-2 years - Shape 1 - Medium Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#CC0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>1-2 years - Shape 2 - Medium Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#CC0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>1-2 years - Shape 3 - Medium Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#CC0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>1-2 years - Shape 4 - Medium Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#CC0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>1-2 years - Shape 5 - Medium Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#CC0000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>3-4 years - International Waters - Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#990000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>3-4 years - Shape 0 - Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#990000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>3-4 years - Shape 1 - Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#990000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>3-4 years - Shape 2 - Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#990000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>3-4 years - Shape 3 - Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#990000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>3-4 years - Shape 4 - Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#990000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>3-4 years - Shape 5 - Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#990000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>5-6 years - International Waters - Very Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#660000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>5-6 years - Shape 0 - Very Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#660000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>5-6 years - Shape 1 - Very Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#660000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>5-6 years - Shape 2 - Very Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#660000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>5-6 years - Shape 3 - Very Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#660000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>5-6 years - Shape 4 - Very Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#660000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>5-6 years - Shape 5 - Very Dark Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#660000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>7-8 years - International Waters - Almost Black Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#330000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>7-8 years - Shape 0 - Almost Black Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#330000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>7-8 years - Shape 1 - Almost Black Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#330000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>7-8 years - Shape 2 - Almost Black Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#330000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>7-8 years - Shape 3 - Almost Black Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#330000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>7-8 years - Shape 4 - Almost Black Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#330000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>7-8 years - Shape 5 - Almost Black Red</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>age_years</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#330000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>9+ years - International Waters - Very Dark (Almost Black)</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>age_years</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#000000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>9+ years - Shape 0 - Very Dark (Almost Black)</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>age_years</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#000000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>9+ years - Shape 1 - Very Dark (Almost Black)</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>age_years</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#000000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>9+ years - Shape 2 - Very Dark (Almost Black)</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>age_years</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#000000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>9+ years - Shape 3 - Very Dark (Almost Black)</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>age_years</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#000000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>9+ years - Shape 4 - Very Dark (Almost Black)</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>age_years</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#000000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>9+ years - Shape 5 - Very Dark (Almost Black)</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>age_years</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#000000</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1.5</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Default rule for NULL country_shape_mod (no country assigned) -->
        <se:Rule>
          <se:Name>Default - Gray Circle (No Country)</se:Name>
          <ogc:Filter>
            <ogc:PropertyIsNull>
              <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
            </ogc:PropertyIsNull>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#888888</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
